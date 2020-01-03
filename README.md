# Mongosquare

- Xcode11에서 Swift Package Manager를 사용해서 Mongokitten을 Swift Package Manager로 빼내고 싶었으나 시도를 해보니 크게 2가지 문제가 있었음
우리가 쓰는 MongoKitten과 최신의 MongoKitten 5와 6 사이의 변화가 커서 쉽게 관련 코드 업데이트가 불가능함. 그리고 Mongosquare에서 필요한 정보를 가지고 오기 위해 보니 internal로 선언된 기능을 많이 사용해야 해서 결국 소스를 수정할 필요가 있음.  Swift Package Manager를 못 쓴다.
남은 이슈는 MongoKitten을 최신 MongoKitten 소스로 업데이트 할 것인가? 업데이트 하면서 최신 MongoKitten의 소스를 고쳐야한다. 일단 보류하고 필요성을 판단해보자

## Mongosquare 구조
- WindowController내의 최상단 컨텐츠뷰가 SplitWrapperView. 여기에  splitViewController를 넣음
- 좌측 사이드바 OutlineViewController
- 실제 접속하는 MongoDB는 OutlineViewController의 connection 변수에서 로컬로 고정되어 있음
- 모델은 SquareConnection -> SquareDatabase -> SquareCollection ->  SquareDocument
- splitViewController에서  sidebarController /  tabViewController /  jsonViewController 구조로 설정
- WindowController의 세그먼트 등에서 UI 이벤트가 발생하면 tabViewController의  activeCollectionViewController를 업데이트 함

### 제대로 동작 안하는 기능
- Collection 추가
- Database 추가: Collection 추가가 안되서 안되는 것인지 모르겠음
- 새 문서 만들어서 저장하면 _id가 추가된 문서가 생성되는데 에디터에 바로 반영 안됨
  - 그래서 Cmd+S로 저장하면 계속 새 문서 추가 됨
- 아웃라인뷰에서 문서 수정시 expand가 다 닫힘. 셀렉션 유지 안됨
- 아웃라인뷰에서 값 수정하고 테이블뷰로 가면 값이 바뀌어 있지 않음
- 아웃라인뷰에서 값 수정하면 JSON 에디터 바뀌는데 테이블뷰에서 변경하면 JSON 에디터 변화없음
- stocks (필드 수십개) 테이블 느림 / 아웃라인뷰 느림
- 아웃라인뷰의 문서 하나에서 프로퍼티 셀렉션을 옮기면 JSON 문서가 바뀜 (문서가 다른 문서로 바뀌는 것은 아닌데 한 문서에서 프로퍼티 순서만 바뀌어서 보이는 듯)
- 테이블뷰가 로드되고 나서 fields를 바꾸면 컬럼이 없어지지 않음
- 문서 타입의 값은 테이블에서 수정 불가능하게

### 앞으로 해야할 기능
- 커넥션 화면
- Outline뷰 서브 문서 표시
- 테이블뷰 서브 문서 표시
- 비동기화. 굉장히 느린 컬렉션이 있는데 누르고 로딩이 오래 걸려도 다른 작업을 할 수 있어야 함. 비동기화를 위해 MongoKitten 버전 업을 해야하나?
- 비동기화를 위해 어떤 작업을 하는지 보여주는 상태바 UI
- fields 프로젝션을 해도 아웃라인뷰의 Value 컬럼에 전체 컬럼수도 표시해야함
