from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.shipr_run_operation import ShiprRunOperation
from ..models.shipr_run_scope_kind import ShiprRunScopeKind
from ..models.shipr_run_state import ShiprRunState
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.shipr_run_summary_type_0 import ShiprRunSummaryType0


T = TypeVar("T", bound="GetV1ShiprRunsResponse200DataItem")


@_attrs_define
class GetV1ShiprRunsResponse200DataItem:
    """
    Attributes:
        id (str | Unset):
        operation (ShiprRunOperation | Unset):
        scope_kind (ShiprRunScopeKind | Unset):
        scope_id (None | str | Unset):
        environments (list[str] | Unset):
        state (ShiprRunState | Unset):
        summary (None | ShiprRunSummaryType0 | Unset):
        started_at (None | str | Unset):
        finished_at (None | str | Unset):
        created (int | Unset): Unix timestamp, in seconds.
        object_ (Literal['shipr.run'] | Unset):
    """

    id: str | Unset = UNSET
    operation: ShiprRunOperation | Unset = UNSET
    scope_kind: ShiprRunScopeKind | Unset = UNSET
    scope_id: None | str | Unset = UNSET
    environments: list[str] | Unset = UNSET
    state: ShiprRunState | Unset = UNSET
    summary: None | ShiprRunSummaryType0 | Unset = UNSET
    started_at: None | str | Unset = UNSET
    finished_at: None | str | Unset = UNSET
    created: int | Unset = UNSET
    object_: Literal["shipr.run"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.shipr_run_summary_type_0 import ShiprRunSummaryType0

        id = self.id

        operation: str | Unset = UNSET
        if not isinstance(self.operation, Unset):
            operation = self.operation.value

        scope_kind: str | Unset = UNSET
        if not isinstance(self.scope_kind, Unset):
            scope_kind = self.scope_kind.value

        scope_id: None | str | Unset
        if isinstance(self.scope_id, Unset):
            scope_id = UNSET
        else:
            scope_id = self.scope_id

        environments: list[str] | Unset = UNSET
        if not isinstance(self.environments, Unset):
            environments = self.environments

        state: str | Unset = UNSET
        if not isinstance(self.state, Unset):
            state = self.state.value

        summary: dict[str, Any] | None | Unset
        if isinstance(self.summary, Unset):
            summary = UNSET
        elif isinstance(self.summary, ShiprRunSummaryType0):
            summary = self.summary.to_dict()
        else:
            summary = self.summary

        started_at: None | str | Unset
        if isinstance(self.started_at, Unset):
            started_at = UNSET
        else:
            started_at = self.started_at

        finished_at: None | str | Unset
        if isinstance(self.finished_at, Unset):
            finished_at = UNSET
        else:
            finished_at = self.finished_at

        created = self.created

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if id is not UNSET:
            field_dict["id"] = id
        if operation is not UNSET:
            field_dict["operation"] = operation
        if scope_kind is not UNSET:
            field_dict["scope_kind"] = scope_kind
        if scope_id is not UNSET:
            field_dict["scope_id"] = scope_id
        if environments is not UNSET:
            field_dict["environments"] = environments
        if state is not UNSET:
            field_dict["state"] = state
        if summary is not UNSET:
            field_dict["summary"] = summary
        if started_at is not UNSET:
            field_dict["started_at"] = started_at
        if finished_at is not UNSET:
            field_dict["finished_at"] = finished_at
        if created is not UNSET:
            field_dict["created"] = created
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.shipr_run_summary_type_0 import ShiprRunSummaryType0

        d = dict(src_dict)
        id = d.pop("id", UNSET)

        _operation = d.pop("operation", UNSET)
        operation: ShiprRunOperation | Unset
        if isinstance(_operation, Unset):
            operation = UNSET
        else:
            operation = ShiprRunOperation(_operation)

        _scope_kind = d.pop("scope_kind", UNSET)
        scope_kind: ShiprRunScopeKind | Unset
        if isinstance(_scope_kind, Unset):
            scope_kind = UNSET
        else:
            scope_kind = ShiprRunScopeKind(_scope_kind)

        def _parse_scope_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        scope_id = _parse_scope_id(d.pop("scope_id", UNSET))

        environments = cast(list[str], d.pop("environments", UNSET))

        _state = d.pop("state", UNSET)
        state: ShiprRunState | Unset
        if isinstance(_state, Unset):
            state = UNSET
        else:
            state = ShiprRunState(_state)

        def _parse_summary(data: object) -> None | ShiprRunSummaryType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                summary_type_0 = ShiprRunSummaryType0.from_dict(data)

                return summary_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | ShiprRunSummaryType0 | Unset, data)

        summary = _parse_summary(d.pop("summary", UNSET))

        def _parse_started_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        started_at = _parse_started_at(d.pop("started_at", UNSET))

        def _parse_finished_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        finished_at = _parse_finished_at(d.pop("finished_at", UNSET))

        created = d.pop("created", UNSET)

        object_ = cast(Literal["shipr.run"] | Unset, d.pop("object", UNSET))
        if object_ != "shipr.run" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'shipr.run', got '{object_}'")

        get_v1_shipr_runs_response_200_data_item = cls(
            id=id,
            operation=operation,
            scope_kind=scope_kind,
            scope_id=scope_id,
            environments=environments,
            state=state,
            summary=summary,
            started_at=started_at,
            finished_at=finished_at,
            created=created,
            object_=object_,
        )

        get_v1_shipr_runs_response_200_data_item.additional_properties = d
        return get_v1_shipr_runs_response_200_data_item

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
